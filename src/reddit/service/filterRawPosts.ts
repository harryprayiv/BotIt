import { PostFilter } from '../model/PostFilter';
import { RawPost } from '../model/RawPost';
import { isPostWithinTimeLimit } from './isPostWithinTimeLimit';
import { logger, LogContext, LogDomain } from '../../logger';

export function filterRawPosts(
  rawPosts: RawPost[],
  { minUpvotes, maxDownvotes, minUpvoteRatio, maxTimeHours }: PostFilter
) {
  let stickiedOrRemoved = 0;
  let notEnoughUpvotes = 0;
  let tooManyDownVotes = 0;
  let badUpvoteRatio = 0;
  let tooOld = 0;
  let noLink = 0;

  const filteredPosts = rawPosts.filter((rawPost) => {
    if (rawPost.data.stickied || rawPost.data.removal_reason) {
      stickiedOrRemoved++;
      return false;
    }

    if (minUpvotes && rawPost.data.ups < minUpvotes) {
      notEnoughUpvotes++;
      return false;
    }

    if (maxDownvotes && rawPost.data.downs > maxDownvotes) {
      tooManyDownVotes++;
      return false;
    }

    if (minUpvoteRatio && rawPost.data.upvote_ratio < minUpvoteRatio) {
      badUpvoteRatio++;
      return false;
    }

    if (maxTimeHours && !isPostWithinTimeLimit(rawPost, maxTimeHours)) {
      tooOld++;
      return false;
    }

    if (
      !rawPost.data.url_overridden_by_dest ||
      rawPost.data.url_overridden_by_dest.includes('redd.it')
    ) {
      noLink++;
      return false;
    }

    return true;
  });

  if (filteredPosts.length > 0) {
    logger(
      LogContext.Info,
      `${filteredPosts.length} viable posts found:`,
      LogDomain.Reddit
    );
    filteredPosts.forEach((post) => {
      logger(
        LogContext.Info,
        `* ${post.data.url_overridden_by_dest} (${post.data.title}) -- ${post.data.ups} Upvotes ${post.data.downs} Downvotes`,
        LogDomain.Reddit
      );
    });
  } else {
    logger(
      LogContext.Info,
      `No valid posts found in the subreddit ${rawPosts[0].data.subreddit}. Here is the breakdown:
* ${stickiedOrRemoved} were stickied or removed
* ${noLink} had no link
* ${tooOld} were too old (max hours: ${maxTimeHours})
* ${notEnoughUpvotes} didn't have enough upvotes (min: ${minUpvotes})
* ${tooManyDownVotes} had too many downvotes (max: ${maxDownvotes})
* ${badUpvoteRatio} had bad upvote ratios (min ratio: ${minUpvoteRatio})

Please try again later or update the config.yml values to adjust your configurations (min upvotes, max downvotes, min ratio)`,
      LogDomain.Reddit
    );
  }

  return filteredPosts;
}